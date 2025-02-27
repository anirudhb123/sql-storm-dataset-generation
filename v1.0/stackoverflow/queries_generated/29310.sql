WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT c.Id) DESC) AS CommentRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(MONTH, -12, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.Tags, u.DisplayName
),
TagStats AS (
    SELECT 
        TAG.tagname,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS TotalComments,
        AVG(v.UpVotesCount) AS AvgUpVotes
    FROM 
        (SELECT DISTINCT unnest(string_to_array(Tags, ',')) AS tagname FROM Posts) TAG
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || TAG.tagname || '%'
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT 
            v.PostId,
            SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount
         FROM 
            Votes v
         GROUP BY 
            v.PostId) v ON p.Id = v.PostId
    GROUP BY 
        TAG.tagname
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    tg.tagname,
    tg.PostCount,
    tg.TotalComments,
    tg.AvgUpVotes
FROM 
    RankedPosts rp
JOIN 
    TagStats tg ON tg.tagname = ANY(string_to_array(rp.Tags, ','))
WHERE 
    rp.CommentRank <= 5
ORDER BY 
    rp.CommentCount DESC, tg.AvgUpVotes DESC;
