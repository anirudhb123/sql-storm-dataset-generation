WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'UpMod') AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'DownMod') AS DownVoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
        JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
        LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
        LEFT JOIN (
            SELECT PostId, string_to_array(substring(Tags, 2, length(Tags)-2), '<>') AS TagArray 
            FROM Posts
        ) AS tag_split ON p.Id = tag_split.PostId
        LEFT JOIN LATERAL (
            SELECT unnest(tag_split.TagArray) AS TagName
        ) t ON TRUE
        JOIN PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, pt.Name
),

TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        OwnerDisplayName,
        CommentCount,
        UpVoteCount,
        DownVoteCount,
        Tags
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)

SELECT 
    trp.PostId,
    trp.Title,
    trp.Body,
    trp.CreationDate,
    trp.OwnerDisplayName,
    trp.CommentCount,
    trp.UpVoteCount,
    trp.DownVoteCount,
    string_agg(tag, ', ') AS Tags
FROM 
    TopRankedPosts trp
    LEFT JOIN unnest(trp.Tags) AS tag ON true
GROUP BY 
    trp.PostId, trp.Title, trp.Body, trp.CreationDate, trp.OwnerDisplayName, 
    trp.CommentCount, trp.UpVoteCount, trp.DownVoteCount
ORDER BY 
    trp.CreationDate DESC;
