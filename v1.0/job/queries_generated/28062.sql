WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        mt.movie_id,
        mt.company_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        movie_keyword mk ON mc.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.movie_id, mt.company_id, cn.name, ct.kind
),
TitleWithAkaNames AS (
    SELECT 
        at.id AS aka_title_id,
        at.title,
        an.name AS aka_name,
        an.person_id,
        RANK() OVER (PARTITION BY at.id ORDER BY an.name) AS name_rank
    FROM 
        aka_title at
    JOIN 
        aka_name an ON at.id = an.id
),
FilteredMovies AS (
    SELECT 
        m.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        k.keywords
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        MovieDetails m ON t.id = m.movie_id
    JOIN 
        RankedTitles rt ON t.id = rt.title_id
    WHERE 
        rt.title_rank <= 5
        AND t.production_year BETWEEN 2000 AND 2023
)
SELECT 
    fm.movie_id,
    fm.movie_title,
    fm.production_year,
    fm.company_name,
    fm.keywords
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC,
    fm.movie_title;
