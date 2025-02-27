WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN vt.Name = 'Favorite' THEN 1 ELSE 0 END) AS Favorites
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        MAX(p.CreationDate) AS LastActivityDate,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostsCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9 -- only BountyClose
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, p.Title
),
RankedPosts AS (
    SELECT 
        ps.*,
        ROW_NUMBER() OVER (ORDER BY ps.CommentCount DESC, ps.TotalBounty DESC) AS Rank
    FROM PostStats ps
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    rp.PostId,
    rp.Title,
    rp.CommentCount,
    rp.TotalBounty,
    rp.LastActivityDate,
    rp.RelatedPostsCount,
    COALESCE(uvs.TotalVotes, 0) AS UserTotalVotes,
    COALESCE(uvs.UpVotes, 0) AS UserUpVotes,
    COALESCE(uvs.DownVotes, 0) AS UserDownVotes,
    CASE 
        WHEN uvs.UpVotes > uvs.DownVotes THEN 'Positive' 
        WHEN uvs.UpVotes < uvs.DownVotes THEN 'Negative' 
        ELSE 'Neutral' 
    END AS UserVoteSentiment
FROM RankedPosts rp
FULL OUTER JOIN UserVoteStats uvs ON uvs.TotalVotes > 0
WHERE rp.Rank <= 10
ORDER BY rp.CommentCount DESC, rp.TotalBounty DESC;
