
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        u.DisplayName AS Author,
        LISTAGG(t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS Tags,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL (SELECT TRIM(value) AS TagName 
                   FROM TABLE(FLATTEN(INPUT => SPLIT(SUBSTR(p.Tags, 2, LENGTH(p.Tags) - 2), '> <')))) 
        ) t ON TRUE
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Body, u.DisplayName, p.PostTypeId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Body,
    rp.Author,
    rp.Tags,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 5 AND (rp.UpVotes - rp.DownVotes) > 0
ORDER BY 
    rp.UpVotes DESC, rp.CreationDate ASC;
