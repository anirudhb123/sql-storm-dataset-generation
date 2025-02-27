WITH RecursiveActorRoles AS (
    SELECT 
        ka.person_id,
        ka.name,
        ct.kind AS role,
        ROW_NUMBER() OVER (PARTITION BY ka.person_id ORDER BY kp.keyword) AS role_rank
    FROM aka_name ka
    JOIN cast_info ci ON ka.person_id = ci.person_id
    JOIN comp_cast_type ct ON ci.person_role_id = ct.id
    LEFT JOIN movie_keyword mk ON ci.movie_id = mk.movie_id
    LEFT JOIN keyword kp ON mk.keyword_id = kp.id
    WHERE kp.keyword IS NOT NULL
), RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(mk.keyword_id) AS keyword_count,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(mk.keyword_id) DESC) AS rank_by_keyword
    FROM aka_title mt
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY mt.id
), NullExample AS (
    SELECT 
        ra.person_id,
        ra.name,
        COALESCE(rr.role, 'No Role Assigned') AS role_desc,
        rm.movie_id,
        rm.title,
        CASE 
            WHEN rm.production_year IS NULL THEN 'Unknown Year'
            ELSE CAST(rm.production_year AS TEXT)
        END AS movie_year
    FROM RecursiveActorRoles ra
    FULL OUTER JOIN RankedMovies rm ON ra.role_rank = rm.rank_by_keyword
    LEFT JOIN (SELECT * FROM info_type WHERE info LIKE '%award%') award_info ON award_info.id = rm.movie_id
), FinalResults AS (
    SELECT 
        ne.person_id,
        ne.name,
        ne.role_desc,
        ne.title,
        ne.movie_year,
        COALESCE(ga.nominated_count, 0) AS awards_nominated,
        COALESCE(ga.won_count, 0) AS awards_won
    FROM NullExample ne
    LEFT JOIN (
        SELECT 
            person_id,
            COUNT(*) FILTER (WHERE note = 'won') AS won_count,
            COUNT(*) FILTER (WHERE note = 'nominated') AS nominated_count
        FROM person_info
        GROUP BY person_id
    ) ga ON ne.person_id = ga.person_id
)
SELECT 
    DISTINCT ON (person_id)
    person_id,
    name,
    role_desc,
    title,
    movie_year,
    awards_nominated,
    awards_won
FROM FinalResults
WHERE person_id IS NOT NULL
  AND role_desc != 'No Role Assigned'
ORDER BY person_id, awards_nominated DESC NULLS LAST;
