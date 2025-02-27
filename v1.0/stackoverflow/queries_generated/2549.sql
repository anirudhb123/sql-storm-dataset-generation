WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswer,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY p.CreationDate) OVER () AS MedianCreationDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.AcceptedAnswerId
),
PopularPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        ViewCount,
        UpVoteCount,
        DownVoteCount,
        ROW_NUMBER() OVER (ORDER BY Score DESC, ViewCount DESC) AS RN
    FROM 
        PostStats
    WHERE 
        UpVoteCount > DownVoteCount
)
SELECT 
    pp.PostId,
    pp.Title, 
    pp.Score, 
    pp.ViewCount, 
    pp.UpVoteCount,
    pp.DownVoteCount,
    CASE 
        WHEN pp.RN <= 10 THEN 'Top Post'
        WHEN pp.ViewCount > 1000 THEN 'Popular Post'
        ELSE 'Regular Post'
    END AS PostCategory,
    (
        SELECT COUNT(DISTINCT u.Id)
        FROM Users u
        JOIN Posts p2 ON u.Id = p2.OwnerUserId
        WHERE p2.Id = pp.PostId
    ) AS UniqueUserContributors,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM PostHistory ph
            WHERE ph.PostId = pp.PostId 
            AND ph.PostHistoryTypeId IN (10, 11)
        ) THEN 'Closed or Reopened'
        ELSE 'Active'
    END AS PostStatus
FROM 
    PopularPosts pp
WHERE 
    pp.RN <= 20
ORDER BY 
    pp.Score DESC, pp.ViewCount DESC;
