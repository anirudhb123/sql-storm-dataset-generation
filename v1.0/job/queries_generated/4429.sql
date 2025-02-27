WITH MovieRanks AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title mt
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
FilteredMovies AS (
    SELECT 
        mr.movie_id,
        mr.title,
        mr.production_year
    FROM 
        MovieRanks mr
    WHERE 
        mr.rank <= 5
)
SELECT 
    fm.title,
    fm.production_year,
    ARRAY_AGG(DISTINCT ak.name) AS actor_names,
    ARRAY_AGG(DISTINCT cn.name) FILTER (WHERE cn.country_code IS NOT NULL) AS production_companies,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = fm.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Awards')) AS awards_count,
    (SELECT STRING_AGG(DISTINCT kw.keyword, ', ') FROM movie_keyword mk JOIN keyword kw ON mk.keyword_id = kw.id WHERE mk.movie_id = fm.movie_id) AS keywords
FROM 
    FilteredMovies fm
LEFT JOIN 
    complete_cast cc ON fm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON fm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    fm.movie_id, fm.title, fm.production_year
ORDER BY 
    fm.production_year DESC, fm.title;
