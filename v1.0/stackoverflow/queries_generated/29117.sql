WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(SUM(v.VoteTypeId = 2)::int, 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3)::int, 0) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id
),

TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.AnswerCount,
        rp.Upvotes,
        rp.Downvotes
    FROM 
        RankedPosts rp
    WHERE
        rp.rn = 1 -- Get the latest question for each user
)

SELECT 
    p.PostId,
    p.Title,
    p.Body,
    p.CreationDate,
    p.AnswerCount,
    p.Upvotes,
    p.Downvotes,
    u.DisplayName AS Author,
    u.Reputation,
    CASE 
        WHEN p.Upvotes > p.Downvotes THEN 'Positive Engagement'
        WHEN p.Upvotes < p.Downvotes THEN 'Negative Engagement'
        ELSE 'Neutral Engagement'
    END AS EngagementType
FROM 
    TopPosts p
JOIN 
    Users u ON p.PostId IN (SELECT AnsweredPostId FROM Posts WHERE ParentId = p.PostId)
WHERE 
    u.Id IS NOT NULL
ORDER BY 
    p.CreationDate DESC;
