WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Considering only questions
),
QuestionWithTags AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    GROUP BY 
        p.PostId, p.Title, p.CreationDate, p.ViewCount
),
UserWithReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 1000 -- Filtering users with high reputation
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
FilteredQuestions AS (
    SELECT 
        q.PostId,
        q.Title,
        q.CreationDate,
        q.ViewCount,
        q.Tags,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        u.Upvotes,
        u.Downvotes
    FROM 
        QuestionWithTags q
    JOIN 
        Users u ON q.PostId = u.Id
    WHERE 
        q.ViewCount > 10 AND 
        u.Reputation > 1000 -- Ensuring quality questions from high reputation users
)
SELECT 
    fq.Title,
    fq.CreationDate,
    fq.ViewCount,
    fq.Tags,
    fq.OwnerDisplayName,
    fq.Reputation,
    fq.Upvotes,
    fq.Downvotes,
    CASE 
        WHEN fq.ViewCount > 100 THEN 'High Viewership' 
        ELSE 'Moderate Viewership' 
    END AS ViewershipCategory
FROM 
    FilteredQuestions fq
ORDER BY 
    fq.Reputation DESC,
    fq.ViewCount DESC;

-- Including a summary of the top 5 tags used in questions by high reputation users
SELECT 
    t.TagName,
    COUNT(p.Id) AS QuestionCount
FROM 
    Tags t
JOIN 
    Posts p ON t.ExcerptPostId = p.Id
WHERE 
    p.PostTypeId = 1 -- Questions
GROUP BY 
    t.TagName
ORDER BY 
    QuestionCount DESC
LIMIT 5;

-- Use a correlated subquery to find the user with the highest score in relation to their questions
SELECT 
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalQuestions,
    (SELECT COUNT(*) FROM Votes v WHERE v.UserId = u.Id AND v.VoteTypeId = 2) AS Upvotes
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
WHERE 
    p.PostTypeId = 1 -- Only considering questions
GROUP BY 
    u.DisplayName
ORDER BY 
    Upvotes DESC
LIMIT 1;
