WITH MovieTitleInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        mk.keyword AS movie_keyword,
        ARRAY_AGG(DISTINCT ak.name) FILTER (WHERE ak.name IS NOT NULL) AS aka_names,
        COUNT(DISTINCT co.id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        aka_name ak ON t.movie_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredTitles AS (
    SELECT 
        mti.title_id,
        mti.title,
        mti.production_year,
        mti.movie_keyword,
        mti.aka_names,
        mti.company_count,
        mti.year_rank
    FROM 
        MovieTitleInfo mti
    WHERE 
        mti.production_year >= 2000
        AND (mti.company_count > 2 OR mti.movie_keyword IS NOT NULL)
),
MostPopularTitles AS (
    SELECT 
        title_id,
        title,
        production_year,
        aka_names,
        RANK() OVER (PARTITION BY production_year ORDER BY year_rank ASC) AS popularity_rank
    FROM 
        FilteredTitles
    WHERE 
        array_length(aka_names, 1) IS NOT NULL
    ORDER BY 
        production_year, popularity_rank
)
SELECT 
    pt.title,
    pt.production_year,
    COALESCE(pt.aka_names[1], 'No Alternate Names') AS primary_aka_name,
    pt.popularity_rank,
    CASE 
        WHEN pt.popularity_rank <= 5 THEN 'Top 5 of the Year'
        WHEN pt.popularity_rank IS NULL THEN 'Rank Undefined'
        ELSE 'Beyond Top 5'
    END AS rank_description,
    STRING_AGG(mk.keyword, ', ') AS keywords
FROM 
    MostPopularTitles pt
LEFT JOIN 
    movie_keyword mk ON pt.title_id = mk.movie_id
WHERE 
    (pt.popularity_rank IS NOT NULL OR pt.popularity_rank > 0)
GROUP BY 
    pt.title, pt.production_year, pt.aka_names, pt.popularity_rank
ORDER BY 
    pt.production_year DESC, pt.popularity_rank ASC;
