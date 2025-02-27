
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        DATEDIFF(MINUTE, p.CreationDate, GETDATE()) AS AgeInMinutes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY DATEDIFF(MINUTE, p.CreationDate, GETDATE()) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE))
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.AgeInMinutes,
        rp.UpVotes,
        rp.DownVotes,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1 
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    fp.CreationDate,
    fp.AgeInMinutes,
    fp.UpVotes - fp.DownVotes AS NetVotes,
    fp.CommentCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList
FROM 
    FilteredPosts fp
LEFT JOIN 
    Tags t ON CHARINDEX(t.TagName, LTRIM(RTRIM(REPLACE(fp.Tags, ',', '')))) > 0
GROUP BY 
    fp.PostId, fp.Title, fp.OwnerDisplayName, fp.CreationDate, 
    fp.AgeInMinutes, fp.UpVotes, fp.DownVotes, fp.CommentCount
ORDER BY 
    NetVotes DESC, fp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
