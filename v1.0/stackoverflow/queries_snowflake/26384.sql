
WITH ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        TRIM(REGEXP_SUBSTR(p.Tags, '[^><]+', 1, seq.n)) AS Tag
    FROM 
        Posts p,
        (SELECT SEQ4() AS n FROM TABLE(GENERATOR(ROWCOUNT => 100))) seq
    WHERE 
        p.PostTypeId = 1 
        AND seq.n <= REGEXP_COUNT(p.Tags, '><') + 1
),
TagStats AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        ProcessedTags
    WHERE Tag IS NOT NULL
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS Rank
    FROM 
        TagStats
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
FinalBenchmark AS (
    SELECT 
        t.Tag,
        t.TagCount,
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ur.BadgeCount,
        ur.TotalViews,
        ur.TotalAnswers
    FROM 
        TopTags t
    JOIN 
        UserReputation ur ON ur.TotalViews > 10000 
)

SELECT 
    fb.Tag,
    fb.TagCount,
    COUNT(DISTINCT fb.UserId) AS UserCount,
    AVG(fb.Reputation) AS AvgReputation,
    SUM(fb.BadgeCount) AS TotalBadges,
    SUM(fb.TotalViews) AS TotalViews,
    SUM(fb.TotalAnswers) AS TotalAnswers
FROM 
    FinalBenchmark fb
GROUP BY 
    fb.Tag, fb.TagCount
ORDER BY 
    fb.TagCount DESC;
