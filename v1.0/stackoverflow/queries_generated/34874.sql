WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.Tags,
        p.PostTypeId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.OwnerUserId,
        a.CreationDate,
        a.Score,
        a.Tags,
        a.PostTypeId,
        Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostCTE r ON a.ParentId = r.PostId
    WHERE 
        a.PostTypeId = 2  -- Join to answers
),

UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Class = 1  -- Focus on Gold badges
    GROUP BY 
        u.Id
),

HotQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  -- Upvotes
    WHERE 
        p.PostTypeId = 1 AND p.Score > 10  -- Filter for popular questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
    HAVING 
        COUNT(DISTINCT v.Id) > 5  -- Must have more than 5 upvotes
)

SELECT 
    r.PostId,
    r.Title AS PostTitle,
    r.OwnerUserId,
    r.CreationDate AS QuestionDate,
    r.Score AS QuestionScore,
    u.DisplayName AS OwnerName,
    u.Reputation AS OwnerReputation,
    ubc.BadgeCount AS OwnerGoldBadgeCount,
    hq.CommentCount AS QuestionCommentCount,
    hq.VoteCount AS QuestionVoteCount,
    r.Level AS PostLevel
FROM 
    RecursivePostCTE r
LEFT JOIN 
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN 
    UserBadgeCounts ubc ON u.Id = ubc.UserId
LEFT JOIN 
    HotQuestions hq ON r.PostId = hq.PostId
WHERE 
    r.Level <= 2  -- Limit to two levels of posts (questions + answers)
ORDER BY 
    r.Score DESC, r.CreationDate ASC;
