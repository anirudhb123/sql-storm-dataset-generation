
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS production_year_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
), TitleKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id, k.keyword
), TitleInfo AS (
    SELECT 
        mi.movie_id,
        LISTAGG(mii.info, ', ') WITHIN GROUP (ORDER BY mii.info) AS movie_info
    FROM movie_info mi
    JOIN movie_info_idx mii ON mi.id = mii.info_type_id
    GROUP BY mi.movie_id
)
SELECT 
    a.name AS actor_name,
    rt.title,
    rt.production_year,
    tk.keyword,
    ti.movie_info
FROM aka_name a
JOIN cast_info c ON a.person_id = c.person_id
JOIN RankedTitles rt ON c.movie_id = rt.title_id
JOIN TitleKeywords tk ON c.movie_id = tk.movie_id
JOIN TitleInfo ti ON c.movie_id = ti.movie_id
WHERE rt.production_year_rank <= 10
ORDER BY rt.production_year DESC, a.name, rt.title;
