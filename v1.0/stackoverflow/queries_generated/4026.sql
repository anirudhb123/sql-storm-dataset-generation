WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND p.Score >= 0
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        us.UserId,
        us.DisplayName,
        us.Reputation
    FROM 
        RankedPosts rp
    JOIN 
        Users us ON rp.PostId IN (SELECT AnswerId FROM Posts WHERE AcceptedAnswerId = rp.PostId)
    WHERE 
        rp.rn = 1
)
SELECT 
    fp.Title,
    fp.CreationDate,
    fp.Score AS PostScore,
    CASE 
        WHEN us.Reputation IS NULL THEN 'No Reputation'
        ELSE us.Reputation::varchar
    END AS ReputationStatus,
    COALESCE(us.BadgeCount, 0) AS BadgeCount,
    (CASE 
        WHEN fp.Score > 100 THEN 'High Score'
        WHEN fp.Score BETWEEN 50 AND 100 THEN 'Medium Score'
        ELSE 'Low Score' 
    END) AS ScoreCategory,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    FilteredPosts fp
LEFT JOIN 
    Users us ON fp.UserId = us.Id
LEFT JOIN 
    Posts p ON fp.PostId = p.Id
LEFT JOIN 
    unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag_name AS tag
LEFT JOIN 
    Tags t ON t.TagName = tag_name
GROUP BY 
    fp.Title, fp.CreationDate, fp.Score, us.Reputation, us.BadgeCount
ORDER BY 
    fp.CreationDate DESC
LIMIT 50;
