WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        COALESCE((
            SELECT COUNT(*) 
            FROM Votes v 
            WHERE v.PostId = p.Id AND v.VoteTypeId = 2
        ), 0) AS UpVotes,
        COALESCE((
            SELECT COUNT(*) 
            FROM Votes v 
            WHERE v.PostId = p.Id AND v.VoteTypeId = 3
        ), 0) AS DownVotes,
        (SELECT STRING_AGG(t.TagName, ', ') 
         FROM Tags t 
         WHERE t.Id IN (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[]))) 
         GROUP BY p.Id) AS PostTags
    FROM 
        Posts p
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.UpVotes,
    rp.DownVotes,
    rp.PostTags
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, rp.PostId ASC;
