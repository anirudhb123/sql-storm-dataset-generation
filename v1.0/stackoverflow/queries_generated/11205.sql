WITH Benchmark AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,   -- UpMod
        SUM(v.VoteTypeId = 3) AS DownVotes, -- DownMod
        COALESCE(b.UserId, -1) AS BadgeOwnerId  -- Assuming we check if the post's owner has badges
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, b.UserId
)
SELECT 
    AVG(Score) AS AvgScore,
    AVG(ViewCount) AS AvgViewCount,
    AVG(CommentCount) AS AvgCommentCount,
    AVG(UpVotes) AS AvgUpVotes,
    AVG(DownVotes) AS AvgDownVotes,
    COUNT(DISTINCT PostId) AS PostCount,
    COUNT(DISTINCT BadgeOwnerId) AS UniqueBadgeOwners
FROM 
    Benchmark;
