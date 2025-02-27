WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'  -- Last year
),
PostVoteSummary AS (
    SELECT
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id
),
TopTags AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(pt.PostId) AS TagCount
    FROM 
        Tags t
    LEFT JOIN 
        PostsTags pt ON pt.TagId = t.Id
    GROUP BY 
        t.Id, t.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    rp.CreationDate,
    rp.OwnerDisplayName,
    CASE 
        WHEN rp.Rank <= 3 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostRankCategory,
    tt.TagName
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteSummary vs ON rp.PostId = vs.PostId
LEFT JOIN 
    PostsTags pt ON rp.PostId = pt.PostId
LEFT JOIN 
    TopTags tt ON pt.TagId = tt.TagId
WHERE 
    rp.Rank <= 10  -- Get top 10 recent questions per user
ORDER BY 
    rp.CreationDate DESC;
