# 1.3.1 (2016-08-24)
- When performing updates do not set use_existing flag on parameters that are
    inherited from existing stacks.

## 1.3.0 (2016-08-12)
- Support passing capabilities using new --capabilities option. No longer set
    CAPABILITY_IAM by default.
- When performing updates use existing parameters by default
- Do not compress template by default (readability vs slight space savings)
- Rubocop code cleanup

## 1.2.0 (2015-10-08)
- Support AWS credential profiles and multiple regions using new --region and
  --profile options.

## 1.1.6 (2015-03-23)

- Bugfix for tag functionality (failed if no tags are specified).

## 1.1.5 (2015-03-23)

- longer default timeout for stack creation (previously was only for stack update).

## 1.1.4 (2015-03-09)

- Support adding custom tags to every created resource

## 1.1.3 (2015-02-09)

- Longer default timeouts for payload and stack creation.
- Require latest version of Cfoo which supports condition functions.
- More responsive status display (resizes with terminal).
- Regression: do not require --existing option.

## 1.1.2 (2015-02-04)

- Allow multiple existing stacks for parameter passthrough.

## 1.1.1 (2015-02-04)

- Improved payload parameters for more flexibility.
- Fix broken update action.

## 1.1.0 (2015-02-03)

- Support passing outputs from existing stacks into parameters.
- Support numeric parameters and tags.

## 1.0.0 (2015-02-02)

- Initial functional release.
