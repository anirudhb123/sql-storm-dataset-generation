WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        RANK() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
StringMatchCounts AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        aka_name ak
    JOIN 
        movie_keyword mk ON ak.person_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        ak.person_id, ak.name
),
MoviesWithKeywords AS (
    SELECT 
        mt.movie_id,
        mt.title,
        string_agg(k.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.movie_id, mt.title
),
CombinedData AS (
    SELECT 
        p.id AS person_id,
        p.name,
        tt.title,
        tt.production_year,
        tt.title_rank,
        mkw.keywords,
        smc.keyword_count
    FROM 
        aka_name p
    JOIN 
        StringMatchCounts smc ON p.person_id = smc.person_id
    JOIN 
        MoviesWithKeywords mkw ON mkw.movie_id = p.person_id
    JOIN 
        RankedTitles tt ON mkw.title = tt.title
)
SELECT 
    cd.person_id,
    cd.name,
    cd.title,
    cd.production_year,
    cd.title_rank,
    cd.keywords,
    cd.keyword_count
FROM 
    CombinedData cd
WHERE 
    cd.title_rank <= 5
ORDER BY 
    cd.production_year DESC, 
    cd.title_rank;
