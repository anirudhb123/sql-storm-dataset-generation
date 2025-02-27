WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER(WHERE vt.Name = 'UpMod') AS UpVotes,
        COUNT(DISTINCT v.Id) FILTER(WHERE vt.Name = 'DownMod') AS DownVotes,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS CreationRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    LEFT JOIN 
        LATERAL string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS tag_array(tag)
    LEFT JOIN 
        Tags t ON tag_array.tag = t.TagName
    GROUP BY 
        p.Id, u.DisplayName
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT CONCAT(ph.CreationDate::date, ': ', pht.Name), '; ') AS HistoryDetails
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.TagsArray,
    phs.HistoryDetails
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.CreationRank <= 10 -- retrieve the 10 most recent posts per type
ORDER BY 
    rp.CreationDate DESC;
