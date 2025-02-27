WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) -- Questions and Answers
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(p.ViewCount) AS AvgViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id
),
TopTaggedPosts AS (
    SELECT 
        t.TagName,
        p.Id AS PostId,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id IN (SELECT UNNEST(string_to_array(p.Tags, '><'))::int)
    GROUP BY 
        t.TagName, p.Id
),
CombinedResults AS (
    SELECT 
        r.PostId,
        r.Title,
        r.ViewCount,
        r.CreationDate,
        u.UserId,
        u.QuestionCount,
        u.AnswerCount,
        u.AvgViewCount,
        u.CommentCount,
        tt.TagName,
        tt.TagCount
    FROM 
        RankedPosts r
    JOIN 
        UserPostStats u ON r.PostId = u.UserId
    LEFT JOIN 
        TopTaggedPosts tt ON r.PostId = tt.PostId
)
SELECT 
    cr.PostId,
    cr.Title,
    cr.ViewCount,
    cr.CreationDate,
    COALESCE(cr.TagName, 'No Tags') AS TagName,
    COALESCE(cr.TagCount, 0) AS TagCount,
    cr.QuestionCount,
    cr.AnswerCount,
    cr.AvgViewCount,
    cr.CommentCount
FROM 
    CombinedResults cr
WHERE 
    cr.PostRank = 1 -- Only top-ranked posts
ORDER BY 
    cr.ViewCount DESC, cr.CreationDate DESC
LIMIT 100;

SET ENABLE_BATTERY_OPTIMIZATION;

EXPLAIN ANALYZE 
SELECT 
    p.Id,
    p.Title,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
    COUNT(c.Id) AS TotalComments
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'
GROUP BY 
    p.Id
HAVING 
    COUNT(DISTINCT c.Id) > 5 -- Only posts with more than 5 comments
ORDER BY 
    TotalBounty DESC;

SET ENABLE_BATTERY_OPTIMIZATION OFF;
