WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UpVoteCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.UserId END) AS DownVoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        rp.Tags,
        CASE 
            WHEN rp.ViewCount > 500 THEN 'High Traffic'
            WHEN rp.ViewCount BETWEEN 100 AND 500 THEN 'Moderate Traffic'
            ELSE 'Low Traffic'
        END AS TrafficLevel
    FROM 
        RankedPosts rp
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.CreationDate,
    pd.ViewCount,
    pd.CommentCount,
    pd.UpVoteCount,
    pd.DownVoteCount,
    pd.Tags,
    pd.TrafficLevel,
    (SELECT 
         STRING_AGG(b.Name, ', ') 
     FROM 
         Badges b 
     WHERE 
         b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = pd.PostId)) AS OwnerBadges
FROM 
    PostDetails pd
ORDER BY 
    pd.ViewCount DESC, pd.CreationDate DESC
LIMIT 100;
