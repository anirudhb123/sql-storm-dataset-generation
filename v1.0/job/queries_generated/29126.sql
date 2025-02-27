WITH MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS companies,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS actors,
        GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword) AS keywords
    FROM aka_title AS mt
    LEFT JOIN movie_companies AS mc ON mt.id = mc.movie_id
    LEFT JOIN company_name AS cn ON mc.company_id = cn.id
    LEFT JOIN cast_info AS ci ON mt.id = ci.movie_id
    LEFT JOIN aka_name AS ak ON ci.person_id = ak.person_id
    LEFT JOIN movie_keyword AS mk ON mt.id = mk.movie_id
    LEFT JOIN keyword AS kw ON mk.keyword_id = kw.id
    WHERE mt.production_year BETWEEN 2000 AND 2023
    GROUP BY mt.id
),
ActorCount AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT actors) AS actor_count
    FROM MovieDetails
    GROUP BY movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.companies,
    ac.actor_count,
    md.keywords
FROM MovieDetails AS md
JOIN ActorCount AS ac ON md.movie_id = ac.movie_id
ORDER BY ac.actor_count DESC, md.production_year DESC;
