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
TitleKeywords AS (
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
TopKeywords AS (
    SELECT 
        movie_id,
        STRING_AGG(keyword, ', ') AS keywords
    FROM 
        TitleKeywords
    GROUP BY 
        movie_id
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        ck.kind AS company_kind,
        COALESCE(gender_counts.male_count, 0) AS male_count,
        COALESCE(gender_counts.female_count, 0) AS female_count,
        CASE 
            WHEN COALESCE(gender_counts.male_count, 0) > COALESCE(gender_counts.female_count, 0) 
            THEN 'Male-Dominated'
            WHEN COALESCE(gender_counts.female_count, 0) > COALESCE(gender_counts.male_count, 0) 
            THEN 'Female-Dominated'
            ELSE 'Gender-Balanced'
        END AS gender_balance,
        tk.keywords
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN (
        SELECT 
            ci.movie_id,
            SUM(CASE WHEN n.gender = 'M' THEN 1 ELSE 0 END) AS male_count,
            SUM(CASE WHEN n.gender = 'F' THEN 1 ELSE 0 END) AS female_count
        FROM 
            cast_info ci
        JOIN 
            name n ON ci.person_id = n.id
        GROUP BY 
            ci.movie_id
    ) AS gender_counts ON gender_counts.movie_id = t.id
    LEFT JOIN 
        TopKeywords tk ON tk.movie_id = t.id
    WHERE 
        t.production_year >= 2000
    ORDER BY 
        t.production_year DESC, 
        t.title
)
SELECT 
    md.title_id,
    md.title,
    md.production_year,
    md.company_kind,
    md.gender_balance,
    md.keywords
FROM 
    MovieDetails md
JOIN 
    RankedTitles rt ON md.movie_id = rt.title_id
WHERE 
    rt.title_rank <= 5
ORDER BY 
    md.production_year DESC, 
    md.male_count DESC;
