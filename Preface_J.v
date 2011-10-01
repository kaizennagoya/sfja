(** * 前書き *)

(* $Date: 2011-06-19 12:51:02 -0400 (Sun, 19 Jun 2011) $ *)

(** この電子文章は「ソフトウェアの基礎（プログラミングとプログラミング言語の数学的理論）」という、大学後半～院生向けの1学期分の講義のために書かれたものです。この講義では、Coq上で関数プログラミング、論理学、演算の意味論、ラムダ計算、静的型システムの基礎を学ぶことができます。

このコースの主な特徴は、教材のテキストがCoqのスクリプトファイルそのものとなっており、学習の進み具合を「形式的」かつ「機械的」にチェックしながら学んでいくことができる、ということです。このコースでは、Coqのインタラクティブモードを使って、ソースを1行1行追いながら動きを理解していきます。講義のほとんどはCoqで組み立てられ、Coq上で作業し演習するようデザインされています。

このファイルは章立てされ整理されており、1学期ぶんの教材として十分で、順番に学習していけるよう、筋道立てて作成されています。さらに加えて、いくつかのトピックについて追加項目があります。 *)



(** * 概要 *)

(** このコースは、いくつかの基礎的なテーマから成っています。
  - ソフトウェア工学のための、数学に根ざした論理学
<<
                論理学                       微積分学
         --------------------   =   ----------------------------
           ソフトウェア工学                機械/土木工学
>>
特に、帰納的に定義された集合や関係とその帰納的な証明は、コンピュータサイエンスのいたるところで見られます。このコースでは、帰納法をあらゆる角度から分析します。

  - 関数プログラミング：ソフトウェア開発者が持つべき道具のうち、重要性が特に増している

       - ソフトウェア開発のメインストリームでの方法論での、先進的なプログラミング手法は、関数プログラミングの影響を日増しに強く受けるようになっています。

       - 特に永続的なデータ構造を用い、状態の変化を避けることで、並列プログラミングをシンプルなものとすることができます。

  - プログラミング言語の基礎（このコースの２番目のパート）

        - 表記法　　厳格に表現するテクニック：新しいプログラム言語や、その特色のストレステスト（これは驚くほど普通に行われていることです！）巨大なソフトウェアシステムの多くは基本的なプログラム言語をサブシステムとして持っています（例：正規表現、コマンドラインフォーマット、設定ファイル、SQL、Flash,PDFなどなど）

        - 毎日ソフトウェア作成に使用しているツールに対して、さらに理解を深める。あなたのお気に入りのプログラミング言語が、動作の裏で何を行っているか。

  - Coq　実用に十分な証明支援器

       - 証明支援器は、ソフトウェアやハードウェア開発の両方でますます一般的になりつつあります。Coqはそういったツールであるだけでなく、それを徹底的に学ぶことで、他のツールの理解にも大幅に有利になるようなものです。

*)


(** * 実際の学習について *)


(** ** 章間の依存関係 *)

(** 章と章の間の依存関係をまとめた図と、学習教材へのパスを、[deps.html]にまとめてあります。 *)


(** ** 学習者に要求される知識的前提 *)

(** この資料は、学部生から博士課程、研究者までの幅広い読者に読んでもらえることを想定しています。プログラミング言語や論理学について前提としている知識はさほど大きくありませんが、数学の十分な学位があると理解は早まるでしょう。 *)



(** * Coqについて *)

(** 我々のこのコースでの「研究所」は、Coq証明支援器です。Coqは以下の二つの機能を併せ持っています。
      - シンプルでいささか風変わりな（しかしそのぶん表現力がある）プログラミング言語で、しかも
      - 論理学で言うところの仮定（プログラムの動作に関する仮定も含む）からスタートし、その正当性の証拠を導き出すためのツールです。

    我々は、この両面を同時に研究していきます。
*)


(** ** 学習に必要なもの *)

(** Coqは、Windowsと多くのUNIX変種（LinuxやMacOSを含む）で動きます。具体的には
       - Coqホームページにある最新版のCoq。（全てのサンプルソースはバージョン8.3でコンパイルできることが確認されていますが、8.2でもおそらく動きます）
       - Coqを対話的に操作するIDE。現在、以下の二つから選択できます。
           - ProofGeneralは、Emacs上に作られたIDEです。すでにEmacsに慣れている人向けのものです。Coqとは別にインストールする必要があります。（詳しくはgoogleで"ProofGeneral"を検索してください）
           - CoqIDEは、スタンドアロンで動作するシンプルなIDEです。Coqと一緒に配布されています。しかしいくつかのプラットホームではGUIライブラリなどの追加パッケージをインストールする必要があります。 *)


(** ** 教材となるCoqファイルの入手方法 *)

(** この教材のリリース版のソース（CoqスクリプトとHTMLファイル）をtarで固めたものが、以下のURLで取得できます。
<<
        http://www.cis.upenn.edu/~bcpierce/sf
>>
    この資料の一部だけを使用したい場合は、tarファイルとなっているリリース版を展開して使用してください。
*)


(** * 練習問題について *)

(** この資料の各章には、たくさんの練習問題がついています。"optional（任意）"と記されたり"recommended（推奨）"とされているものもあります。"任意"とされていない問題までやることで、その章で学ぶべきことを6～8時間（長い章でも）の学習で理解できるようになっています。

    練習問題についている"スターレーティング"には、以下のような意味があります。

       - ★：多くの読者が1～2分でできる簡単な問題。"推奨"と明示しているものはありませんが、どちらかというと全て"推奨"とされるべきものです。読者は、この問題に取り組んで、このレベルの問題に慣れておくべきです。

       - ★★：　素直で簡単な問題（5～10分でできるでしょう）

       - ★★★：　少し考えないといけない問題（15～30分ほどかかるでしょう）

       - ★★★★：　さらに難しい問題（1～2時間）
*)


(** * 推奨書籍 *)

(** 「あとがき （[Postscript]）」の章に、読んでおいて損はない本、、テキストをあげておきました。 *)


(** * 教育関係者へ *)

(** この資料を自分のコースで使おうと思った場合、ほぼまちがいなくあなたは書き直したり、追加したりしたいところが出てくるでしょう。そういった貢献は大歓迎です。

ぜひBenjamin Pierceまでemailをください。そうすれば、あなた用のsubversionのリポジトリとメーリングリストのアカウントを用意します。リポジトリには、READMEファイルがありますので、次にどうすべきかはそれを参照してください。 *)



