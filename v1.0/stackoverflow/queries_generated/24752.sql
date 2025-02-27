WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        p.Tags
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Select only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostsWithReputation AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        ur.Reputation,
        ur.UpVoteCount,
        ur.DownVoteCount,
        ur.BadgeCount
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
)
SELECT 
    pwr.PostId,
    pwr.Title,
    pwr.CreationDate,
    pwr.Score,
    pwr.Reputation,
    pwr.UpVoteCount,
    pwr.DownVoteCount,
    pwr.BadgeCount,
    (CASE 
        WHEN pwr.Score >= 100 THEN 'Highly Rated' 
        WHEN pwr.Score BETWEEN 50 AND 99 THEN 'Moderately Rated' 
        ELSE 'Low Rated' 
     END) AS PostRating,
    (SELECT STRING_AGG(t.TagName, ', ') FROM Tags t WHERE t.Id IN (
        SELECT UNNEST(string_to_array(pwr.Tags, '><'))::int
    )) AS TagNames
FROM 
    PostsWithReputation pwr
WHERE 
    pwr.Reputation > 100
    AND pwr.UpVoteCount > pwr.DownVoteCount
    AND pwr.Reputation IS NOT NULL
    AND (NOT EXISTS (SELECT 1 FROM Posts WHERE Id = pwr.PostId AND ClosedDate IS NOT NULL) 
         OR EXISTS (SELECT 1 FROM PostHistory ph 
                    WHERE ph.PostHistoryTypeId IN (10, 11)
                    AND ph.PostId = pwr.PostId))
ORDER BY 
    pwr.CreationDate DESC
FETCH FIRST 10 ROWS ONLY;
