function out=style_transfer(style_in, im_in_name, style_ex, im_ex_name, opt) 

  % Ex: style_transfer flickr2 2187287549_74951db8c2_o martin 0;
  addpath('../libs/image_pyramids/');

  if ~exist('opt')
    opt.write_output=true;
    opt.transfer_eye=true;
    opt.recomp=true; %Re-comppute the matching
    opt.show_match=true; %Visualize the warping
    opt.verbose=true;
  end

  % Reading data
  command_str1 = ['sudo python extract_crop_test.py input.png'];
  command_str2 = ['sudo python extract_crop_test.py example.png'];
  [status1, c_out1] = system(command_str1);
  [status2, c_out2] = system(command_str2);
  if status1 ~= 0 || status2 ~= 0
      display ('exitting! some error in the python')
      display(c_out1);
      display(c_out2);
  end
  
   in_image = im2double(imread('input_cr.png'));
   ex_image = im2double(imread('example_cr.png'));
  
  if(numel(in_image) > numel(ex_image))
      [to_m, to_n, d] = size(ex_image);
      in_image = imresize(in_image,[to_m, to_n]);
  else if(numel(in_image) < numel(ex_image))
          [to_m, to_n, d] = size(in_image);
          ex_image = imresize(ex_image, [to_m, to_n]);
      end
  end
  imwrite(in_image, 'input_cr.png', 'PNG');
  imwrite(ex_image, 'example_cr.png', 'PNG');
  
  command_str1 = 'sudo python extract_trimap_test.py input_cr.png';
  command_str2 = 'sudo python extract_trimap_test.py example_cr.png';
  [status1, c_out1] = system(command_str1);
  [status2, c_out2] = system(command_str2);
  if status1 ~= 0 || status2 ~= 0
      display ('exitting! some error in the python')
      display(c_out1);
      display(c_out2);
  end
  im_in = in_image;
  im_ex = ex_image;
  %in_trimap = im2double(imread('input_cr_trimap.png'));
  %ex_trimap = im2double(imread('example_cr_trimap.png'));
  %in_trimap = in_trimap(:,:,1);
  %ex_trimap = ex_trimap(:,:,1);
  
  mask_in = double(test_get_a_matt('input_cr', 'yosh', 'png'));
  mask_ex = double(test_get_a_matt('example_cr', 'yosh', 'png'));
  %mask_in = demo_test('input');
  %mask_ex = demo_test('example');
  %mask_in = knn_matting_user_input_image('input_cr.png', 'input_cr_trimap.png');
  %mask_ex = knn_matting_user_input_image('example_cr.png', 'example_cr_trimap.png');
  %mask_in = knn_matting(im_in, in_trimap, 100, 1);
  %mask_ex = knn_matting(im_ex, ex_trimap, 100, 1);
  %imwrite(uint8(mask_in), 'input_cr_mask.png', 'PNG');
  %imwrite(uint8(mask_ex), 'example_cr_mask.png', 'PNG');
  %mask_in = mask_in./255;
  %mask_ex = mask_ex./255;
  
  %im_in = im2double(imread('input.png'));
  %im_ex = im2double(imread('input.png'));
  %im_in = im2double(imread('input.png'));
  %[to_m, to_n, to_ch] = size(im_in);
  %im_ex = im2double(imread('example.png'));
  %im_ex = imresize(im_ex, [to_m, to_n]);
  %imwrite(im_ex, 'example.png');
  %im_in = im2double(imread(sprintf('../../data/%s/fgs/%s.png', style_in, im_in_name)));
  %im_ex = im2double(imread(sprintf('../../data/%s/imgs/%s.png', style_ex, im_ex_name)));
  %im_in=imresize(im2double(imread(sprintf('../../data/%s/imgs/%s.png', style_in, im_in_name))), 0.5);
  %im_ex=imresize(im2double(imread(sprintf('../../data/%s/imgs/%s.png', style_ex, im_ex_name))), 0.5);
  
  %im_ex = im2double(imread('karthi.jpg'));
  %[m_test, n_test, d_test] = size(im_in);
  %im_ex = imresize(im_ex, [m_test, n_test]);
  
  %mask_in = test_get_a_matt(im_in, im_in_name, 'png');
  %mask_ex = test_get_a_matt(im_ex, im_ex_name, 'png');
  %mask_in=im2double(imread(sprintf('../../data/%s/masks/%s.png', style_in, im_in_name)));
  %mask_ex=im2double(imread(sprintf('../../data/%s/masks/%s.png', style_ex, im_ex_name)));
  %mask_in = 255.*ones(to_m, to_n, to_ch);
  %mask_ex = 255.*ones(to_m, to_n, to_ch);
  %mask_in = im2double(imread('input_cr_trimap.png'))

  %bg_ex = im2double(imread(sprintf('../../data/%s/bgs/%s.jpg', style_ex, im_ex_name)));
  bg_ex = zeros(size(im_in));
  %im_ex = mask_ex.*im_ex;

  %%%%--- Dense matching ----%%%%
  print_v('Computing the correspondence ...\n', opt.verbose);
  if opt.recomp
    %[vxm vym] = morph(style_ex, im_ex_name, style_in, im_in_name);
    [vxm vym] = morph('','example_cr.png', '', 'input_cr.png');
    im_ex_w =warpImage(im_ex, vxm, vym);
    [vx vy]=sift_flow(im_in, im_ex_w);
    [vxf vyf]=thresh_v(vx+vxm, vy+vym);
    save('match.mat', 'vxf', 'vyf');
  else
    load('match.mat');
  end

  close all;
  if opt.show_match
    im_ex_wf =warpImage(im_ex, vxf, vyf);
    figure;imshow(0.5*(im_in+im_ex_wf));drawnow;
    pause
  end

  %%%% --- Local Matching ----%%%%
  print_v('Local transfer ...\n', opt.verbose);
  if strcmp(style_ex, 'martin')
    nch=3;
  else
    nch=1;
  end
  nch = 3;
  e_0 = 1e-4;
  gain_max = 2.8;
  gain_min = 0.9;
  hist_transfer=true;

  % Replace the input background with example.
  %im_in = mask_in.*im_in + (1-mask_in).*bg_ex;

  im_in = RGB2Lab(im_in);
  im_ex = RGB2Lab(im_ex);

  out = zeros(size(im_in));
  for ch = 1 : nch
    nLevel = 3;
    % Disabled mask-based Laplacian for now.
    pyr_in = laplacian_pyramid(im_in(:,:,ch), nLevel, ...
                        false, bin_alpha(mask_in(:,:,1)));
    pyr_ex = laplacian_pyramid(im_ex(:,:,ch), nLevel, ...
        false, bin_alpha(mask_in(:,:,1))|bin_alpha(mask_ex(:,:,1)));

    pyr_out = pyr_in;

    for i = 1 : nLevel-1
      r = 2*2^(i+1);

      l_in = pyr_in{i};
      l_ex = pyr_ex{i};
      l_ex = warpImage(l_ex, vxf, vyf);
      e_in = imfilter(l_in.^2, fspecial('gaussian', ceil(6*[r r]), r));
      e_ex = imfilter(l_ex.^2, fspecial('gaussian', ceil(6*[r r]), r));
      gain = (e_ex./(e_in+e_0)).^0.5;

      % Clamping gain maps
      gain(gain>gain_max)=gain_max;
      gain(gain<gain_min)=gain_min;
      l_new = l_in.*gain;

      if hist_transfer
        minus = l_in <0;
        l_new = HistTransferOneD(abs(l_new), abs(l_ex));
        l_new(minus) = -1*l_new(minus);
      end
      pyr_out{i} = l_new; 
    end

    pyr_out{end} = warpImage(pyr_ex{end}, vxf, vyf);
    if ch==1 && hist_transfer
      pyr_out{end} = HistTransferOneD(pyr_out{end}, pyr_ex{end});
    end
    out(:,:,ch) = sum_pyramid(pyr_out);
  end
  out = Lab2RGB(out);
  im_in = Lab2RGB(im_in);

  % Matting 
  out = mask_in.*out + (1-mask_in).*bg_ex;
  %out = mask_in.*out;

  %%%%% ---- Eye highlight transfer ----%%%%
  if ~opt.transfer_eye
    print_v('Eye highlight transfer ...\n', opt.verbose);
    alpha_l = im2double(imread(sprintf('../../data/eyes/%s/001_alpha_l.png', style_ex)));
    alpha_r = im2double(imread(sprintf('../../data/eyes/%s/001_alpha_r.png', style_ex)));
    fg_l = im2double(imread(sprintf('../../data/eyes/%s/001_fg_l.png', style_ex)));
    fg_r = im2double(imread(sprintf('../../data/eyes/%s/001_fg_r.png', style_ex)));

    model = csvread(sprintf('../../data/%s/landmarks/%s.lm', style_in, im_in_name));
    leye_center = round(mean(model(37:42, :),1));
    reye_center = round(mean(model(43:48, :),1));

    half_width= 75;
    half_height = 50;
    leye_raw=im_in(leye_center(2)-half_height : leye_center(2) + half_height,...
                 leye_center(1)-half_width  : leye_center(1) + half_width,:);
    reye_raw=im_in(reye_center(2)-half_height : reye_center(2) + half_height,...
                 reye_center(1)-half_width  : reye_center(1) + half_width,:);
    leye = out(leye_center(2)-half_height : leye_center(2) + half_height,...
                 leye_center(1)-half_width  : leye_center(1) + half_width,:);
    reye = out(reye_center(2)-half_height : reye_center(2) + half_height,...
                 reye_center(1)-half_width  : reye_center(1) + half_width,:);
    leye_new = eye_transfer(leye, leye_raw, alpha_l, fg_l);
    reye_new = eye_transfer(reye, reye_raw, alpha_r, fg_r);
    out(leye_center(2)-half_height : leye_center(2) + half_height,...
      leye_center(1)-half_width  : leye_center(1) + half_width,:)=leye_new;
    out(reye_center(2)-half_height : reye_center(2) + half_height,...
      reye_center(1)-half_width  : reye_center(1) + half_width,:)=reye_new;
  end
imshow(out, []);
  %if opt.write_output
  %  imwrite(out, sprintf('../output/%s/%s/%s.jpg', ...
   %       style_in, style_ex, im_in_name), 'Quality', 100); 
  %end

  
function output=bin_alpha(input) 
output=input;
% In case the mask is not perfec / too small
output(output<0.5)=0;
output(output>=0.5)=1;
se = strel('disk', 71);  
output = imdilate(output,se);

% Add a small number to avoid crazy
eps=1e-2;
output = output + eps;

function print_v(msg, verbose)
if verbose
  fprintf(msg);
end
