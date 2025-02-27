WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore, 
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate >= NOW() - INTERVAL '2 years'
),
PostActivity AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        pht.Name AS PostHistoryType,
        COUNT(ph.Id) AS HistoryCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistory ph ON rp.PostId = ph.PostId
    LEFT JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, rp.ViewCount, rp.CommentCount, rp.UpVotes, rp.DownVotes, pht.Name
),
PopularPosts AS (
    SELECT 
        pa.*,
        CASE 
            WHEN pa.UpVotes > pa.DownVotes THEN 'Popular'
            WHEN pa.UpVotes < pa.DownVotes THEN 'Controversial'
            ELSE 'Neutral'
        END AS Popularity
    FROM 
        PostActivity pa
    WHERE 
        pa.CommentCount > 5 OR pa.HistoryCount > 2
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.Score,
    pp.ViewCount,
    pp.CommentCount,
    pp.UpVotes,
    pp.DownVotes,
    pp.Popularity,
    COALESCE(STRING_AGG(DISTINCT pt.Name, ', '), 'No Tags') AS PostTags
FROM 
    PopularPosts pp
LEFT JOIN 
    Posts p ON pp.PostId = p.Id
LEFT JOIN 
    LATERAL (
        SELECT 
            UNNEST(STRING_TO_ARRAY(p.Tags, ',')) AS Tag
    ) AS tag_array ON TRUE
LEFT JOIN 
    Tags pt ON TRIM(tag_array.Tag) = pt.TagName
GROUP BY 
    pp.PostId, pp.Title, pp.Score, pp.ViewCount, pp.CommentCount, pp.UpVotes, pp.DownVotes, pp.Popularity
ORDER BY 
    pp.Score DESC, pp.ViewCount DESC
LIMIT 100;
