
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        LISTAGG(DISTINCT t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL FLATTEN(input => SPLIT(TRIM(BOTH '<>' FROM p.Tags), '> <')) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag.VALUE
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
), 
PostScores AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        TotalComments,
        UpVotes - DownVotes AS NetVotes,
        ROW_NUMBER() OVER (ORDER BY (UpVotes - DownVotes) DESC, TotalComments DESC) AS Ranking
    FROM 
        RankedPosts
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.TotalComments,
    ps.NetVotes,
    ps.Ranking,
    rp.Tags
FROM 
    PostScores ps
JOIN 
    RankedPosts rp ON ps.PostId = rp.PostId
WHERE 
    ps.Ranking <= 10;
