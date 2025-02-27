WITH UserScore AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 100 -- Only consider users with reputation greater than 100
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Only posts from the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
RankedPosts AS (
    SELECT 
        ps.*,
        RANK() OVER (ORDER BY ps.Score DESC) AS PostRank,
        RANK() OVER (ORDER BY ps.CommentCount DESC) AS CommentRank
    FROM 
        PostStats ps
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    COALESCE(SUM(rp.Score), 0) AS TotalScore,
    COALESCE(SUM(rp.CommentCount), 0) AS TotalComments,
    COALESCE(SUM(rp.UpVoteCount), 0) AS TotalUpVotes,
    COALESCE(SUM(rp.DownVoteCount), 0) AS TotalDownVotes,
    ROW_NUMBER() OVER (ORDER BY us.Reputation DESC) AS UserRank
FROM 
    UserScore us
LEFT JOIN 
    RankedPosts rp ON rp.PostId IN (
        SELECT p.Id 
        FROM Posts p 
        WHERE p.OwnerUserId = us.UserId
    )
GROUP BY 
    us.UserId, us.DisplayName, us.Reputation
HAVING 
    COALESCE(SUM(rp.Score), 0) > 0 -- Only include users with positive score from posts
ORDER BY 
    UserRank;
