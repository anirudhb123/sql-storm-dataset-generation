WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(RankedPosts.ViewCount) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        RankedPosts ON p.Id = RankedPosts.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.QuestionCount,
    us.AnswerCount,
    us.AvgViewCount,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount
FROM 
    UserStatistics us
JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
WHERE 
    us.Reputation > 100 -- Filtering users with high reputation
ORDER BY 
    rp.Score DESC, us.QuestionCount DESC
LIMIT 50;
