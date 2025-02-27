WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS ViewRank,
        COUNT(v.Id) AS VoteCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  -- UpVotes only
    WHERE p.PostTypeId = 1  -- Only questions
    GROUP BY p.Id, p.Title, p.Tags, p.ViewCount, p.CreationDate
),
MostVotedPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.ViewCount,
        rp.VoteCount,
        ROW_NUMBER() OVER (ORDER BY rp.VoteCount DESC) AS VoteRank
    FROM RankedPosts rp
    WHERE rp.ViewRank <= 10  -- Get top 10 viewed posts for each tag
),
PostWithBadges AS (
    SELECT
        mp.Title,
        mp.Tags,
        mp.ViewCount,
        mp.VoteCount,
        b.Name AS BadgeName,
        b.Class
    FROM MostVotedPosts mp
    LEFT JOIN Badges b ON b.UserId = (
        SELECT OwnerUserId FROM Posts WHERE Id = mp.PostId
    ) 
    WHERE b.Name IS NOT NULL
),
FinalOutput AS (
    SELECT
        pw.Title,
        pw.Tags,
        pw.ViewCount,
        pw.VoteCount,
        COALESCE(b.BadgeName, 'No Badge') AS BadgeName,
        COALESCE(b.Class, 0) AS BadgeClass
    FROM PostWithBadges pw
    LEFT JOIN Badges b ON b.UserId IN (
        SELECT OwnerUserId 
        FROM Posts 
        WHERE Id = pw.PostId
    ) 
)

SELECT 
    Title,
    Tags,
    ViewCount,
    VoteCount,
    CASE 
        WHEN BadgeClass = 1 THEN 'Gold' 
        WHEN BadgeClass = 2 THEN 'Silver' 
        WHEN BadgeClass = 3 THEN 'Bronze' 
        ELSE 'No Badge' 
    END AS BadgeLevel
FROM FinalOutput
ORDER BY VoteCount DESC, ViewCount DESC
LIMIT 50;
