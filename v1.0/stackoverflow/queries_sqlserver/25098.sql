
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        LEN(REPLACE(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '>', ',')) - LEN(REPLACE(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), ',', '')) + 1 AS TagCount,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        rp.*,
        ROUND(CAST(UpVoteCount AS decimal) / NULLIF((UpVoteCount + DownVoteCount), 0) * 100, 2) AS UpVotePercentage
    FROM 
        RankedPosts rp
    WHERE 
        TagCount > 2 AND Rank = 1
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    fp.CreationDate,
    fp.TagCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    fp.UpVotePercentage
FROM 
    FilteredPosts fp
ORDER BY 
    fp.UpVotePercentage DESC, 
    fp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
