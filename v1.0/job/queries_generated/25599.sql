WITH RankedTitles AS (
    SELECT
        a.title AS title,
        a.production_year AS year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER(PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_within_year
    FROM
        aka_title a
    JOIN
        movie_companies mc ON a.id = mc.movie_id
    JOIN
        cast_info c ON c.movie_id = a.id
    GROUP BY
        a.title, a.production_year
),
PopularKeywords AS (
    SELECT 
        mk.movie_id, 
        k.keyword,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
),
TopMovies AS (
    SELECT 
        rt.title, 
        rt.year, 
        rt.cast_count,
        pk.keyword,
        pk.keyword_count,
        RANK() OVER (ORDER BY rt.cast_count DESC) AS global_rank
    FROM 
        RankedTitles rt
    JOIN 
        PopularKeywords pk ON rt.title = (SELECT title FROM aka_title WHERE id = pk.movie_id) 
    WHERE 
        rt.rank_within_year <= 10 AND pk.keyword_count > 1
)
SELECT 
    t.year,
    t.title,
    t.cast_count,
    t.keyword,
    t.keyword_count,
    COALESCE(BRAvg.cast_count, 0) AS avg_cast_count,
    COALESCE(BRAvg.avg_keyword_count, 0) AS avg_keyword_count
FROM 
    TopMovies t
LEFT JOIN (
    SELECT 
        year,
        AVG(cast_count) AS cast_count,
        AVG(keyword_count) AS avg_keyword_count
    FROM 
        TopMovies
    GROUP BY 
        year
) AS BRAvg ON t.year = BRAvg.year
ORDER BY 
    t.cast_count DESC, 
    t.year DESC, 
    t.keyword_count DESC;
