WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Only consider posts from the last year
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title,
        rp.Score,
        rp.CommentCount,
        p.OwnerUserId,
        u.Reputation,
        CASE 
            WHEN rp.CommentCount >= 5 THEN 'Highly Engaged'
            WHEN rp.CommentCount IS NULL THEN 'No Engagement'
            ELSE 'Some Engagement'
        END AS EngagementLevel
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.PostRank = 1 -- Get only the top post per user
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts 
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 10
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '1 month'  -- Votes from the last month
    GROUP BY 
        v.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.CommentCount,
    tp.Reputation,
    tp.EngagementLevel,
    COALESCE(rv.UpVotes, 0) AS RecentUpVotes,
    COALESCE(rv.DownVotes, 0) AS RecentDownVotes,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = tp.PostId AND ph.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount,
    pt.Tag,
    pt.TagCount
FROM 
    TopPosts tp
LEFT JOIN 
    RecentVotes rv ON tp.PostId = rv.PostId
LEFT JOIN 
    PopularTags pt ON pt.Tag = ANY(string_to_array(tp.Tags, '><'))
WHERE 
    tp.Reputation BETWEEN 100 AND 1000  -- Users with moderate reputation
ORDER BY 
    tp.Score DESC, tp.CommentCount DESC
LIMIT 50;
