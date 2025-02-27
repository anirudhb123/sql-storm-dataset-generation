WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Questions only
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, ',')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions only
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 5
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        COALESCE(pt.TagName, 'No Tags') AS TagName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PopularTags pt ON pt.TagName = ANY (string_to_array((SELECT Tags from Posts WHERE Id = rp.PostId), ','))
),
FinalBenchmark AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.CommentCount,
        pd.UpVotes,
        pd.DownVotes,
        COALESCE(pt.Name, 'No Close Reason') AS CloseReason
    FROM 
        PostDetails pd
    LEFT JOIN 
        PostHistory ph ON pd.PostId = ph.PostId AND ph.PostHistoryTypeId = 10  -- Checking for close history
    LEFT JOIN 
        CloseReasonTypes pt ON ph.Comment::int = pt.Id
)
SELECT 
    *,
    CASE 
        WHEN UpVotes + DownVotes = 0 THEN 'No Votes'
        ELSE (UpVotes::float / NULLIF(UpVotes + DownVotes, 0)) * 100
    END AS VotePercentage
FROM 
    FinalBenchmark
ORDER BY 
    UpVotes DESC, CommentCount DESC;
