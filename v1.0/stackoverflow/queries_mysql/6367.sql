
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.UserId END) AS UpVoteCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.UserId END) AS DownVoteCount,
        @row_number := IF(@current_user = p.OwnerUserId, @row_number + 1, 1) AS Rank,
        @current_user := p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId,
        (SELECT @row_number := 0, @current_user := NULL) AS init
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    ra.PostId,
    ra.Title,
    ra.CreationDate,
    ra.Score,
    ra.ViewCount,
    ra.CommentCount,
    ra.UpVoteCount,
    ra.DownVoteCount,
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    ua.TotalPosts,
    ua.TotalScore,
    ua.TotalUpVotes,
    ua.TotalDownVotes
FROM 
    RankedPosts ra
JOIN 
    UserActivity ua ON ra.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = ua.UserId)
WHERE 
    ra.Rank <= 5
ORDER BY 
    ra.Score DESC, ra.CreationDate DESC;
