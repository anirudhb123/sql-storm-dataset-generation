WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS QuestionCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        t.TagName 
    ORDER BY 
        QuestionCount DESC
    LIMIT 10
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT b.Id) AS BadgesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Questions only
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    r.PostId,
    r.Title,
    r.Body,
    r.Tags,
    r.CreationDate,
    r.ViewCount,
    r.Score,
    pt.TagName AS PopularTag,
    us.DisplayName AS UserDisplayName,
    us.QuestionsAsked,
    us.BadgesReceived
FROM 
    RankedPosts r
LEFT JOIN 
    PopularTags pt ON r.Tags LIKE '%' || pt.TagName || '%'
JOIN 
    Users u ON u.Id = r.OwnerUserId
JOIN 
    UserStats us ON u.Id = us.UserId
WHERE 
    r.Rank <= 5 -- Top 5 questions per type
ORDER BY 
    r.Score DESC, 
    r.ViewCount DESC;
