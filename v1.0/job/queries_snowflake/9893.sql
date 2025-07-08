WITH ActorDetails AS (
    SELECT akn.id AS aka_id, akn.name AS actor_name, ci.movie_id, ci.nr_order, ci.note AS cast_note
    FROM aka_name akn
    JOIN cast_info ci ON akn.person_id = ci.person_id
),
MovieDetails AS (
    SELECT mt.id AS movie_id, mt.title AS movie_title, mt.production_year, kt.kind AS genre
    FROM aka_title mt
    JOIN kind_type kt ON mt.kind_id = kt.id
),
CompanyInfo AS (
    SELECT mc.movie_id, cn.name AS company_name, ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
CompleteInfo AS (
    SELECT ad.actor_name, md.movie_title, md.production_year, ci.company_name, ci.company_type, ad.cast_note
    FROM ActorDetails ad
    JOIN MovieDetails md ON ad.movie_id = md.movie_id
    JOIN CompanyInfo ci ON md.movie_id = ci.movie_id
)
SELECT actor_name, movie_title, production_year, company_name, company_type, cast_note
FROM CompleteInfo
WHERE production_year > 2000
ORDER BY production_year DESC, actor_name;
