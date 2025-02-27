WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.PostTypeId,
        p.OwnerUserId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- Upvotes and Downvotes
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.PostTypeId, p.OwnerUserId, p.ViewCount
), UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(case when p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(case when p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COUNT(c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
), ClosePosts AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate AS CloseDate,
        crt.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment::int = crt.Id 
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
), HighlyActiveUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.QuestionCount,
        ua.AnswerCount,
        ua.CommentCount,
        RANK() OVER (ORDER BY (ua.QuestionCount + ua.AnswerCount + ua.CommentCount) DESC) AS UserRank
    FROM 
        UserActivity ua
    WHERE 
        (ua.QuestionCount + ua.AnswerCount + ua.CommentCount) > 5 -- Only users with significant activity
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.PostTypeId,
    ua.DisplayName AS UserDisplayName,
    COALESCE(c.CloseDate, 'No Closure') AS ClosureDate,
    COALESCE(c.CloseReason, 'Not Applicable') AS ClosureReason,
    rp.VoteCount,
    HighlyActiveUsers.UserRank
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    ClosePosts c ON rp.PostId = c.PostId
LEFT JOIN 
    HighlyActiveUsers ON u.Id = HighlyActiveUsers.UserId
WHERE 
    rp.Rank <= 10 
    AND (rp.ViewCount > 100 OR rp.CreationDate < NOW() - INTERVAL '6 months') -- Posts with a lot of views or older than 6 months
ORDER BY 
    rp.Score DESC, 
    ClosureDate DESC NULLS LAST
LIMIT 50;
