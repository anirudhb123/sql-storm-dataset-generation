WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.OwnerUserId
),

UserStats AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = u.Id) AS PostCount,
        SUM(b.Class) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),

FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CommentCount,
        rp.Tags,
        us.DisplayName,
        us.Reputation,
        us.PostCount,
        us.BadgeCount,
        CASE 
            WHEN rp.Score > 100 THEN 'High Scoring'
            WHEN rp.Score BETWEEN 50 AND 100 THEN 'Medium Scoring'
            ELSE 'Low Scoring'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.PostOwnerUserId = us.Id
    WHERE 
        rp.CommentCount > 5 
        AND us.Reputation > 1000
)

SELECT 
    fp.*,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = fp.PostId AND ph.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount,
    (SELECT MAX(ph.CreationDate) FROM PostHistory ph WHERE ph.PostId = fp.PostId) AS LastEditedDate
FROM 
    FilteredPosts fp
WHERE 
    fp.Reputation > 0
ORDER BY 
    fp.Score DESC, 
    fp.CommentCount DESC
LIMIT 100;
