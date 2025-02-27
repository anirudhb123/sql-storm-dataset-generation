WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.PostTypeId,
        p.OwnerUserId,
        ROW_NUMBER() OVER(PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2)::int AS UpVotes,
        SUM(v.VoteTypeId = 3)::int AS DownVotes
    FROM 
        Posts p 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId, p.OwnerUserId
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.UpVotes + rp.DownVotes > 0 THEN CAST(rp.UpVotes AS float) / (rp.UpVotes + rp.DownVotes)
            ELSE NULL
        END AS VoteRatio
    FROM 
        RankedPosts rp 
    WHERE 
        rp.rn = 1 
        AND rp.Score > (SELECT AVG(Score) FROM Posts) 
        AND rp.ViewCount > 100
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Class = 1 OR b.Class = 2
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        ub.UserId,
        u.DisplayName,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        RANK() OVER(ORDER BY COALESCE(ub.BadgeCount, 0) DESC) AS UserRank
    FROM 
        UserBadges ub
    RIGHT JOIN 
        Users u ON ub.UserId = u.Id
    WHERE 
        u.Reputation > 1000
),
FinalBenchmark AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.CreationDate,
        pp.Score,
        pp.ViewCount,
        pp.CommentCount,
        pp.UpVotes,
        pp.DownVotes,
        pp.VoteRatio,
        tu.DisplayName AS TopUser,
        tu.BadgeCount AS UserBadgeCount
    FROM 
        PopularPosts pp
    LEFT JOIN 
        TopUsers tu ON pp.OwnerUserId = tu.UserId
)
SELECT 
    fb.PostId,
    fb.Title,
    fb.CreationDate,
    fb.Score,
    fb.ViewCount,
    fb.CommentCount,
    fb.UpVotes,
    fb.DownVotes,
    fb.VoteRatio,
    fb.TopUser,
    fb.UserBadgeCount,
    CASE 
        WHEN fb.UserBadgeCount IS NULL THEN 'No Badges'
        ELSE 'Has Badges'
    END AS UserBadgeStatus,
    COALESCE((SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
              FROM Tags t 
              WHERE t.Id IN (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'))::int)) 
              AND p.PostTypeId = 1), 'No Tags') AS AssociatedTags
FROM 
    FinalBenchmark fb
WHERE 
    fb.VoteRatio IS NOT NULL 
ORDER BY 
    fb.Score DESC, fb.ViewCount DESC;

