
WITH RecursiveTitleInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        c.name AS actor_name,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank,
        LEFT(c.name, 3) AS name_first_three,
        CASE 
            WHEN ci.note IS NULL THEN 'No Notes' 
            ELSE ci.note 
        END AS cast_note
    FROM 
        cast_info ci
    JOIN 
        aka_name c ON ci.person_id = c.person_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        COUNT(*) AS company_count,
        SUM(CASE WHEN ct.kind ILIKE '%production%' THEN 1 ELSE 0 END) AS prod_company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rti.title,
    rti.production_year,
    cd.actor_name,
    cd.actor_rank,
    ci.company_name,
    ci.company_count,
    ci.prod_company_count,
    mk.keywords
FROM 
    RecursiveTitleInfo rti
LEFT JOIN 
    CastDetails cd ON rti.title_id = cd.movie_id AND cd.actor_rank <= 5
LEFT JOIN 
    CompanyInfo ci ON rti.title_id = ci.movie_id
LEFT JOIN 
    MovieKeywords mk ON rti.title_id = mk.movie_id
WHERE 
    rti.title_rank = 1
ORDER BY 
    rti.production_year ASC, rti.title ASC, cd.actor_rank;
