WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        unnest(string_to_array(p.Tags, ',')) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON tag = t.TagName
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, U.DisplayName
), 
PostStatistics AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        UpVotes,
        DownVotes,
        CommentCount,
        Tags,
        RANK() OVER (ORDER BY Score DESC, ViewCount DESC) AS Rank
    FROM 
        RankedPosts
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.OwnerDisplayName,
    PS.UpVotes,
    PS.DownVotes,
    PS.CommentCount,
    PS.Tags
FROM 
    PostStatistics PS
WHERE 
    PS.Rank <= 10
ORDER BY 
    PS.Rank;
