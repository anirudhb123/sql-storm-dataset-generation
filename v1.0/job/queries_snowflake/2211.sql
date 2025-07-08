
WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        t.id
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
TitleKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        MAX(pt.role) AS leading_role
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type pt ON ci.role_id = pt.id
    GROUP BY 
        ci.movie_id
),
OrderedMovies AS (
    SELECT 
        rt.title,
        rt.production_year,
        COALESCE(td.keywords, 'No Keywords') AS keywords,
        COALESCE(cd.total_cast, 0) AS total_cast,
        cd.leading_role,
        rt.id
    FROM 
        RankedTitles rt
    LEFT JOIN 
        TitleKeywords td ON rt.id = td.movie_id
    LEFT JOIN 
        CastDetails cd ON rt.id = cd.movie_id
    WHERE 
        rt.year_rank <= 5
)
SELECT 
    om.title,
    om.production_year,
    om.keywords,
    om.total_cast,
    om.leading_role,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = om.id) AS complete_cast_count
FROM 
    OrderedMovies om
WHERE 
    om.total_cast > 0
ORDER BY 
    om.production_year DESC, 
    om.title ASC;
