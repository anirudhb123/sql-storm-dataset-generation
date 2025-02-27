WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ARRAY_LENGTH(string_to_array(p.Tags, '>'), 1) AS TagCount,
        ROW_NUMBER() OVER (PARTITION BY substring(p.Tags FROM '([^<]*)') ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND -- only questions
        p.CreationDate > now() - INTERVAL '1 year' -- questions from the last year
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.ViewCount) AS TotalViewCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND -- only questions
        p.CreationDate > now() - INTERVAL '1 year' -- questions from the last year
    GROUP BY 
        u.Id, u.DisplayName
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViewCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags ILIKE '%' || t.TagName || '%'
    WHERE 
        p.CreationDate > now() - INTERVAL '1 year' AND -- questions from the last year
        p.PostTypeId = 1 -- only questions
    GROUP BY 
        t.TagName
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.QuestionCount,
    up.TotalViewCount,
    up.Upvotes,
    up.Downvotes,
    rp.Title,
    rp.TagCount,
    rp.Score,
    ts.PostCount AS TagPostCount,
    ts.TotalViewCount AS TagTotalViewCount
FROM 
    UserActivity up
JOIN 
    RankedPosts rp ON up.QuestionCount > 0
LEFT JOIN 
    TagStatistics ts ON rp.Tags ILIKE '%' || ts.TagName || '%'
WHERE 
    rp.rn = 1 -- Get the most recent question per tag
ORDER BY 
    up.TotalViewCount DESC,
    up.Upvotes DESC;
