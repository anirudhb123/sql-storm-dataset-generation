WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        P.PostTypeId,
        U.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS rn
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
        AND P.Score >= 5
),
ClosedPostHistory AS (
    SELECT 
        Ph.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory Ph
    WHERE 
        Ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        Ph.PostId
),
TopTags AS (
    SELECT 
        T.TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts P
    JOIN 
        Tags T ON T.Id = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><')::int[])
    GROUP BY 
        T.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 5
),
UserVotes AS (
    SELECT 
        U.Id AS UserId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.CreationDate,
    RP.OwnerName,
    CPH.CloseCount,
    U.TagName,
    CASE 
        WHEN UV.UpVotes > UV.DownVotes THEN 'Positive'
        WHEN UV.UpVotes < UV.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS UserSentiment,
    COALESCE(UV.UpVotes, 0) AS UserUpVotes,
    COALESCE(UV.DownVotes, 0) AS UserDownVotes
FROM 
    RankedPosts RP
LEFT JOIN 
    ClosedPostHistory CPH ON RP.PostId = CPH.PostId
CROSS JOIN 
    (SELECT TagName FROM TopTags) U
LEFT JOIN 
    UserVotes UV ON UV.UserId = RP.PostId
WHERE 
    RP.rn = 1 
    AND (CPH.CloseCount IS NULL OR CPH.CloseCount < 5)
ORDER BY 
    RP.Score DESC, 
    RP.CreationDate DESC;
