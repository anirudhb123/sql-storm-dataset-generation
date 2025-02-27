WITH RawPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.LastActivityDate,
        p.Tags,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -2, GETDATE())
),
RankedPosts AS (
    SELECT 
        rp.*,
        ROW_NUMBER() OVER (PARTITION BY rp.OwnerUserId ORDER BY rp.Score DESC) AS UserRank,
        RANK() OVER (ORDER BY rp.Score DESC) AS GlobalRank,
        DENSE_RANK() OVER (ORDER BY rp.ViewCount DESC) AS ViewRank
    FROM 
        RawPosts rp
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        ub.BadgeCount,
        ub.HighestBadgeClass,
        rp.UserRank,
        rp.GlobalRank,
        rp.ViewRank,
        DATEPART(YEAR, rp.PostCreationDate) AS YearPosted
    FROM 
        RankedPosts rp
    LEFT JOIN UserBadges ub ON rp.OwnerUserId = ub.UserId
)
SELECT 
    ps.YearPosted,
    ps.OwnerDisplayName,
    COUNT(ps.PostId) AS TotalPosts,
    SUM(ps.Score) AS TotalScore,
    AVG(ps.ViewCount) AS AvgViewCount,
    MAX(ps.BadgeCount) AS MaxUserBadgeCount,
    STRING_AGG(DISTINCT CASE WHEN ps.HighestBadgeClass = 1 THEN 'Gold' 
                              WHEN ps.HighestBadgeClass = 2 THEN 'Silver' 
                              WHEN ps.HighestBadgeClass = 3 THEN 'Bronze' 
                         END, ', ') AS BadgeTypes
FROM 
    PostStats ps
GROUP BY 
    ps.YearPosted, ps.OwnerDisplayName
HAVING 
    COUNT(ps.PostId) > 5 AND MAX(ps.Score) > 10
ORDER BY 
    ps.YearPosted DESC, TotalScore DESC;
