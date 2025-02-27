WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount
),
UserInfo AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        u.Views,
        COALESCE(b.Name, 'No Badge') AS BadgeName,
        COUNT(ps.PostId) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Class = 1 -- Gold badges only
    LEFT JOIN 
        PostStats ps ON u.Id = ps.PostId AND ps.RecentPostRank = 1
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName, u.Views, b.Name
),
QualifiedPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.ViewCount,
        ps.CommentCount,
        CASE 
            WHEN up.UpVoteCount IS NULL THEN 0 
            ELSE up.UpVoteCount 
        END AS UpVoteCount,
        CASE 
            WHEN down.DownVoteCount IS NULL THEN 0 
            ELSE down.DownVoteCount 
        END AS DownVoteCount
    FROM 
        PostStats ps
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS UpVoteCount 
        FROM Votes 
        WHERE VoteTypeId = 2 
        GROUP BY PostId
    ) up ON ps.PostId = up.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS DownVoteCount 
        FROM Votes 
        WHERE VoteTypeId = 3 
        GROUP BY PostId
    ) down ON ps.PostId = down.PostId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.Views,
    u.BadgeName,
    qp.Title,
    qp.Score,
    qp.ViewCount,
    qp.CommentCount,
    qp.UpVoteCount,
    qp.DownVoteCount,
    CASE 
        WHEN qp.Score < 0 THEN 'Needs Attention'
        WHEN qp.Score = 0 THEN 'Neutral'
        WHEN qp.Score BETWEEN 1 AND 10 THEN 'Moderately Liked'
        ELSE 'Highly Liked' 
    END AS PostRating,
    NULLIF(DATE_PART('year', AGE(CURRENT_TIMESTAMP, u.CreationDate)), NULL) AS AccountAgeInYears
FROM 
    UserInfo u
JOIN 
    QualifiedPosts qp ON u.TotalPosts > 0
ORDER BY 
    u.Reputation DESC, qp.Score DESC
FETCH FIRST 10 ROWS ONLY;
