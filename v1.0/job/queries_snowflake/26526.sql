WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        AVG(mi.info_type_id) AS avg_info_type
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN movie_info mi ON t.id = mi.movie_id
    GROUP BY t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.keyword_count,
        rt.avg_info_type,
        RANK() OVER (ORDER BY rt.keyword_count DESC, rt.production_year DESC) AS rank
    FROM RankedTitles rt
)
SELECT 
    ak.name AS actor_name,
    tt.title AS movie_title,
    tc.kind AS company_type,
    tt.production_year,
    tt.keyword_count,
    tt.avg_info_type
FROM TopMovies tt
JOIN complete_cast cc ON tt.title_id = cc.movie_id
JOIN cast_info ci ON cc.subject_id = ci.person_id
JOIN aka_name ak ON ci.person_id = ak.person_id
JOIN movie_companies mc ON mc.movie_id = tt.title_id
JOIN company_type tc ON mc.company_type_id = tc.id
WHERE tt.rank <= 10
ORDER BY tt.keyword_count DESC, tt.production_year DESC;
