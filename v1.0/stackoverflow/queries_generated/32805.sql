WITH RECURSIVE UserVoteCount AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostWithVotes AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 4 THEN 1 ELSE 0 END), 0) AS OffensiveVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostHistoryAgg AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 END) AS SuggestedEditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(*) AS TagCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = p.Tags::text[]::int[]
    GROUP BY 
        t.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
FinalResults AS (
    SELECT 
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        pvc.TotalVotes,
        pwv.UpVotes,
        pwv.DownVotes,
        pwv.OffensiveVotes,
        pha.CloseReopenCount,
        pha.DeleteCount,
        pha.SuggestedEditCount,
        STRING_AGG(pt.TagName, ', ') AS AssociatedTags
    FROM 
        PostWithVotes pwv
    JOIN 
        Posts p ON pwv.PostId = p.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        UserVoteCount pvc ON u.Id = pvc.UserId
    LEFT JOIN 
        PostHistoryAgg pha ON p.Id = pha.PostId
    LEFT JOIN 
        LATERAL (SELECT 
                      t.TagName 
                  FROM 
                      Tags t 
                  WHERE 
                      t.Id = ANY(STRING_TO_ARRAY(p.Tags, '><')::int[])) AS pt ON TRUE
    GROUP BY 
        p.Title, p.CreationDate, u.DisplayName, pvc.TotalVotes, pwv.UpVotes, pwv.DownVotes, pwv.OffensiveVotes, pha.CloseReopenCount, pha.DeleteCount, pha.SuggestedEditCount
)
SELECT *
FROM 
    FinalResults
ORDER BY 
    UpVotes DESC, CreationDate DESC
LIMIT 20;
