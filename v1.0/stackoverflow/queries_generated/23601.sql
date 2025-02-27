WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
        ARRAY_AGG(DISTINCT SUBSTRING(t.TagName FROM 1 FOR 10)) AS ShortTags
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Tags t ON t.Id = ANY(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><')::int[])
    WHERE
        p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
    GROUP BY
        p.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Rank,
        rp.OwnerDisplayName,
        rp.ShortTags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 
        AND (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) > 10
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS UpVoteCount,
        MAX(v.CreationDate) AS LastVoted
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= (CURRENT_DATE - INTERVAL '30 days')
    GROUP BY 
        v.PostId
)
SELECT
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.Rank,
    fp.OwnerDisplayName,
    fp.ShortTags,
    COALESCE(rv.UpVoteCount, 0) AS RecentUpVoteCount,
    rv.LastVoted,
    CASE 
        WHEN fp.Score > 50 THEN 'Highly Rated' 
        WHEN fp.ViewCount > 1000 THEN 'Popular'
        ELSE 'Standard'
    END AS PostCategory
FROM 
    FilteredPosts fp
LEFT JOIN 
    RecentVotes rv ON fp.PostId = rv.PostId
WHERE 
    EXISTS (
        SELECT 1
        FROM Comments c
        WHERE c.PostId = fp.PostId
        HAVING COUNT(*) > 5
    ) 
ORDER BY 
    fp.CreationDate DESC, 
    fp.Score DESC
LIMIT 50;
