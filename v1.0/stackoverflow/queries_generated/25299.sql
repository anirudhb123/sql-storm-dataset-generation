WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Selecting only questions
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Questions from the last year
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 100 -- Only users with significant reputation
    GROUP BY 
        u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        ua.UserId,
        ua.DisplayName,
        ua.CommentCount,
        ua.UpVoteCount,
        ua.DownVoteCount,
        ua.TotalBounties
    FROM 
        RankedPosts rp
    JOIN 
        UserActivity ua ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ua.UserId)
)

SELECT 
    pm.Title,
    pm.CreationDate,
    pm.ViewCount,
    pm.Score,
    pm.AnswerCount,
    pm.DisplayName AS Author,
    pm.CommentCount,
    pm.UpVoteCount,
    pm.DownVoteCount,
    pm.TotalBounties
FROM 
    PostMetrics pm
WHERE 
    pm.Rank <= 10 -- Top 10 ranked questions
ORDER BY 
    pm.Score DESC, 
    pm.ViewCount DESC;
